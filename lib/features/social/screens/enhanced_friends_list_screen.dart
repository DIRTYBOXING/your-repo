import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../shared/services/auth_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/services/enhanced_friends_service.dart';
import '../../../shared/models/friend_model.dart';
import '../../messaging/services/messaging_service.dart';
import '../../../shared/widgets/dfc_network_image.dart';
import '../../../core/theme/glass_panel.dart';

/// ═══════════════════════════════════════════════════════════════════════════
/// ENHANCED FRIENDS LIST SCREEN
/// ═══════════════════════════════════════════════════════════════════════════
///
/// Features:
/// - Friend count badge
/// - Online status indicators
/// - Recent activity display
/// - Quick actions (message, call, profile)
/// - Search and filter
/// - Sort options (recent, alphabetical, online first)
/// - Pull to refresh
/// ═══════════════════════════════════════════════════════════════════════════
class EnhancedFriendsListScreen extends StatefulWidget {
  const EnhancedFriendsListScreen({super.key});

  @override
  State<EnhancedFriendsListScreen> createState() =>
      _EnhancedFriendsListScreenState();
}

class _EnhancedFriendsListScreenState extends State<EnhancedFriendsListScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  FriendSortOption _sortOption = FriendSortOption.recent;
  bool _onlineOnly = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final friendsService = context.watch<EnhancedFriendsService>();
    final userId = friendsService.currentUserId;

    if (userId == null) {
      return Scaffold(
        backgroundColor: AppTheme.primaryBackground,
        appBar: AppBar(
          backgroundColor: AppTheme.cardBackground,
          foregroundColor: Colors.white,
          title: const Text('Friends'),
        ),
        body: const Center(
          child: Text(
            'Please log in to view friends',
            style: TextStyle(color: Colors.white),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppTheme.primaryBackground,
      appBar: AppBar(
        backgroundColor: AppTheme.cardBackground,
        foregroundColor: Colors.white,
        title: Row(
          children: [
            const Text('Friends'),
            const SizedBox(width: 8),
            StreamBuilder<int>(
              stream: friendsService.streamFriendCount(),
              builder: (context, snapshot) {
                final count = snapshot.data ?? 0;
                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.neonCyan.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppTheme.neonCyan),
                  ),
                  child: Text(
                    '$count',
                    style: const TextStyle(
                      color: AppTheme.neonCyan,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                );
              },
            ),
          ],
        ),
        actions: [
          // Pending requests badge
          StreamBuilder<int>(
            stream: friendsService.streamPendingRequestCount(),
            builder: (context, snapshot) {
              final count = snapshot.data ?? 0;
              return Stack(
                children: [
                  IconButton(
                    icon: const Icon(Icons.person_add),
                    onPressed: () {
                      context.push('/friend-requests');
                    },
                    tooltip: 'Friend Requests',
                  ),
                  if (count > 0)
                    Positioned(
                      right: 8,
                      top: 8,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: AppTheme.errorColor,
                          shape: BoxShape.circle,
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 18,
                          minHeight: 18,
                        ),
                        child: Text(
                          count > 9 ? '9+' : '$count',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
          PopupMenuButton<FriendSortOption>(
            icon: const Icon(Icons.sort),
            onSelected: (option) {
              setState(() => _sortOption = option);
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: FriendSortOption.recent,
                child: Text('Most Recent'),
              ),
              const PopupMenuItem(
                value: FriendSortOption.alphabetical,
                child: Text('A-Z'),
              ),
              const PopupMenuItem(
                value: FriendSortOption.onlineFirst,
                child: Text('Online First'),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Search friends...',
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () {
                                _searchController.clear();
                                setState(() => _searchQuery = '');
                              },
                            )
                          : null,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onChanged: (value) {
                      setState(() => _searchQuery = value.toLowerCase());
                    },
                  ),
                ),
                const SizedBox(width: 8),
                FilterChip(
                  label: const Text('Online'),
                  selected: _onlineOnly,
                  onSelected: (selected) {
                    setState(() => _onlineOnly = selected);
                  },
                  selectedColor: AppTheme.neonCyan.withValues(alpha: 0.3),
                ),
              ],
            ),
          ),

          // Friends list
          Expanded(
            child: StreamBuilder<List<Friend>>(
              stream: friendsService.streamFriends(userId),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(color: AppTheme.neonCyan),
                  );
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Text(
                        'Error: ${snapshot.error}',
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                  );
                }

                var friends = snapshot.data ?? [];

                // Apply filters
                if (_searchQuery.isNotEmpty) {
                  friends = friends.where((friend) {
                    return friend.friendName.toLowerCase().contains(
                      _searchQuery,
                    );
                  }).toList();
                }

                if (_onlineOnly) {
                  friends = friends.where((friend) => friend.isOnline).toList();
                }

                // Apply sorting
                _sortFriends(friends);

                if (friends.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.people_outline,
                          size: 80,
                          color: Colors.grey.withValues(alpha: 0.5),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _searchQuery.isNotEmpty
                              ? 'No friends found'
                              : 'No friends yet',
                          style: Theme.of(
                            context,
                          ).textTheme.titleLarge?.copyWith(color: Colors.white),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _searchQuery.isNotEmpty
                              ? 'Try a different search'
                              : 'Start connecting with fighters!',
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(color: Colors.white70),
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton(
                          onPressed: () {
                            context.push('/find-friends');
                          },
                          child: const Text('Find Friends'),
                        ),
                      ],
                    ),
                  );
                }

                return RefreshIndicator(
                  onRefresh: () async {
                    // Trigger refresh
                    setState(() {});
                  },
                  child: ListView.builder(
                    itemCount: friends.length,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemBuilder: (context, index) {
                      return FriendListTile(
                        friend: friends[index],
                        onTap: () =>
                            context.push('/user/${friends[index].friendId}'),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          context.push('/find-friends');
        },
        icon: const Icon(Icons.person_add),
        label: const Text('Find Friends'),
        backgroundColor: AppTheme.neonCyan,
      ),
    );
  }

  void _sortFriends(List<Friend> friends) {
    switch (_sortOption) {
      case FriendSortOption.recent:
        friends.sort((a, b) => b.connectedAt.compareTo(a.connectedAt));
        break;
      case FriendSortOption.alphabetical:
        friends.sort((a, b) => a.friendName.compareTo(b.friendName));
        break;
      case FriendSortOption.onlineFirst:
        friends.sort((a, b) {
          if (a.isOnline != b.isOnline) {
            return a.isOnline ? -1 : 1;
          }
          return b.connectedAt.compareTo(a.connectedAt);
        });
        break;
    }
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// FRIEND LIST TILE — Individual friend card
// ═══════════════════════════════════════════════════════════════════════════
class FriendListTile extends StatelessWidget {
  final Friend friend;
  final VoidCallback onTap;

  const FriendListTile({super.key, required this.friend, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GlassPanel(
      padding: EdgeInsets.zero,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            children: [
              // Avatar with online indicator
              Stack(
                children: [
                  DfcCircleAvatar(
                    imageUrl: friend.friendPhotoUrl,
                    radius: 28,
                    backgroundColor: AppTheme.cardBackground,
                    borderColor: Colors.white.withValues(alpha: 0.08),
                    borderWidth: 1,
                    fallbackText: friend.friendName.isNotEmpty
                        ? friend.friendName[0].toUpperCase()
                        : '?',
                  ),
                  if (friend.isOnline)
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        width: 14,
                        height: 14,
                        decoration: BoxDecoration(
                          color: AppTheme.success,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Theme.of(context).cardColor,
                            width: 2,
                          ),
                        ),
                      ),
                    ),
                ],
              ),

              const SizedBox(width: 12),

              // Friend info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            friend.friendName,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (friend.mutualFriends > 0)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: AppTheme.neonCyan.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              '${friend.mutualFriends} mutual',
                              style: const TextStyle(
                                fontSize: 11,
                                color: AppTheme.neonCyan,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          _getRoleIcon(friend.friendRole),
                          size: 14,
                          color: Colors.grey,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          friend.friendRole.toUpperCase(),
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(width: 8),
                        if (friend.lastActive != null && !friend.isOnline)
                          Text(
                            'Active ${_formatTimeAgo(friend.lastActive!)}',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        if (friend.isOnline)
                          const Text(
                            'Online now',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppTheme.success,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),

              // Quick actions
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.message),
                    iconSize: 20,
                    onPressed: () => _openDirectChat(context, friend),
                    tooltip: 'Message',
                  ),
                  PopupMenuButton(
                    icon: const Icon(Icons.more_vert, size: 20),
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'profile',
                        child: Row(
                          children: [
                            Icon(Icons.person, size: 20),
                            SizedBox(width: 8),
                            Text('View Profile'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'stats',
                        child: Row(
                          children: [
                            Icon(Icons.bar_chart, size: 20),
                            SizedBox(width: 8),
                            Text('View Stats'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'invite_training',
                        child: Row(
                          children: [
                            Icon(Icons.fitness_center, size: 20),
                            SizedBox(width: 8),
                            Text('Invite to Training'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'invite_event',
                        child: Row(
                          children: [
                            Icon(Icons.event, size: 20),
                            SizedBox(width: 8),
                            Text('Invite to Event'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'send_support',
                        child: Row(
                          children: [
                            Icon(
                              Icons.favorite,
                              color: AppTheme.neonPink,
                              size: 20,
                            ),
                            SizedBox(width: 8),
                            Text('Send Support'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'unfriend',
                        child: Row(
                          children: [
                            Icon(
                              Icons.person_remove,
                              color: AppTheme.errorColor,
                              size: 20,
                            ),
                            SizedBox(width: 8),
                            Text(
                              'Remove Friend',
                              style: TextStyle(color: AppTheme.errorColor),
                            ),
                          ],
                        ),
                      ),
                    ],
                    onSelected: (value) {
                      if (value == 'profile') {
                        onTap();
                        // } else if (value == 'stats') {
                        //   _viewFriendStats(context, friend);
                        // } else if (value == 'invite_training') {
                        //   _inviteToTraining(context, friend);
                        // } else if (value == 'invite_event') {
                        //   _inviteToEvent(context, friend);
                        // } else if (value == 'send_support') {
                        //   _sendSupport(context, friend);
                      } else if (value == 'unfriend') {
                        _showUnfriendDialog(context, friend);
                      }
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      ),
    );
  }

  Future<void> _openDirectChat(BuildContext context, Friend friend) async {
    final auth = context.read<AuthService>();
    final currentUser = auth.currentUser;
    if (currentUser == null) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please log in to message friends.')),
        );
      }
      return;
    }

    try {
      final conversationId = await context
          .read<MessagingService>()
          .createConversation(
            currentUserId: currentUser.uid,
            currentUserName: currentUser.displayName ?? 'You',
            currentUserPhotoUrl: currentUser.photoURL ?? '',
            otherUserId: friend.friendId,
            otherUserName: friend.friendName,
            otherUserPhotoUrl: friend.friendPhotoUrl,
          );

      if (!context.mounted) return;
      context.push(
        '/messaging/chat/$conversationId',
        extra: {
          'otherName': friend.friendName,
          'otherPhotoUrl': friend.friendPhotoUrl,
          'otherUserId': friend.friendId,
        },
      );
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not open chat: $e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
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

  void _showUnfriendDialog(BuildContext context, Friend friend) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove Friend'),
        content: Text(
          'Are you sure you want to remove ${friend.friendName} from your friends?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              final service = context.read<EnhancedFriendsService>();
              try {
                await service.removeFriend(friend.friendId);
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        '${friend.friendName} removed from friends',
                      ),
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error: $e'),
                      backgroundColor: AppTheme.errorColor,
                    ),
                  );
                }
              }
            },
            child: const Text(
              'Remove',
              style: TextStyle(color: AppTheme.errorColor),
            ),
          ),
        ],
      ),
    );
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

enum FriendSortOption { recent, alphabetical, onlineFirst }
