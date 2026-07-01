import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../shared/widgets/dfc_network_image.dart';

import '../../../core/theme/app_theme.dart';
import '../../../shared/services/auth_service.dart';
import '../../../shared/services/enhanced_friends_service.dart';
import '../../../shared/models/friend_model.dart';

class FriendsListScreen extends StatefulWidget {
  const FriendsListScreen({super.key});

  @override
  State<FriendsListScreen> createState() => _FriendsListScreenState();
}

class _FriendsListScreenState extends State<FriendsListScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchText = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentUserId = context.read<AuthService>().currentUser?.uid;
    final friendsService = context.read<EnhancedFriendsService>();

    if (currentUserId == null) {
      return Scaffold(
        backgroundColor: AppTheme.primaryBackground,
        appBar: AppBar(
          backgroundColor: AppTheme.cardBackground,
          title: const Text('Friends', style: TextStyle(color: Colors.white)),
          iconTheme: const IconThemeData(color: AppTheme.neonCyan),
        ),
        body: const Center(
          child: Text('Please sign in', style: TextStyle(color: Colors.white)),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppTheme.primaryBackground,
      appBar: AppBar(
        backgroundColor: AppTheme.cardBackground,
        title: const Text('Friends', style: TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: AppTheme.neonCyan),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: TextField(
              controller: _searchController,
              onChanged: (value) =>
                  setState(() => _searchText = value.trim().toLowerCase()),
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Check names for work leads (e.g. Mark)',
                hintStyle: TextStyle(
                  color: Colors.white.withValues(alpha: 0.45),
                ),
                prefixIcon: const Icon(Icons.search, color: AppTheme.neonCyan),
                filled: true,
                fillColor: AppTheme.cardBackground,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: AppTheme.neonCyan.withValues(alpha: 0.25),
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: AppTheme.neonCyan.withValues(alpha: 0.25),
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: StreamBuilder<List<Friend>>(
              stream: friendsService.streamFriends(currentUserId),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(color: AppTheme.neonCyan),
                  );
                }

                final friends = snapshot.data ?? const <Friend>[];

                if (friends.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.group_outlined,
                          size: 64,
                          color: AppTheme.neonCyan.withValues(alpha: 0.3),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'No friends yet',
                          style: TextStyle(color: Colors.white70, fontSize: 16),
                        ),
                        const SizedBox(height: 8),
                        TextButton(
                          onPressed: () => context.go('/explore'),
                          child: const Text(
                            'Find people in Explore',
                            style: TextStyle(color: AppTheme.neonCyan),
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: friends.length,
                  itemBuilder: (context, index) {
                    return _FriendCard(
                      friend: friends[index],
                      ownerUserId: currentUserId,
                      searchText: _searchText,
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _FriendCard extends StatelessWidget {
  final Friend friend;
  final String ownerUserId;
  final String searchText;

  const _FriendCard({
    required this.friend,
    required this.ownerUserId,
    required this.searchText,
  });

  @override
  Widget build(BuildContext context) {
    final name = friend.friendName;
    final photoUrl =
        friend.friendPhotoUrl.isNotEmpty ? friend.friendPhotoUrl : null;
    final userId = friend.friendId;

    if (searchText.isNotEmpty && !name.toLowerCase().contains(searchText)) {
      return const SizedBox.shrink();
    }

    return Card(
      color: AppTheme.cardBackground,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: AppTheme.neonCyan.withValues(alpha: 0.3)),
      ),
      child: ListTile(
        onTap: () => context.push('/user/$userId'),
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: AppTheme.neonCyan, width: 1.5),
          ),
          child: ClipOval(
            child: photoUrl != null
                ? DfcNetworkImage(
                    url: photoUrl,
                  )
                : const Icon(Icons.person, color: AppTheme.neonCyan),
          ),
        ),
        title: Row(
          children: [
            Flexible(
              child: Text(
                name,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            if (friend.isOnline) ...[
              const SizedBox(width: 6),
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: Color(0xFF4CAF50),
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ],
        ),
        subtitle: Text(
          '${friend.friendRole.isNotEmpty ? friend.friendRole[0].toUpperCase() + friend.friendRole.substring(1) : "Friend"} • Tap briefcase to mark as work lead',
          style: const TextStyle(color: Colors.white54),
        ),
        trailing: SizedBox(
          width: 92,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                onPressed: () async {
                  await FirebaseFirestore.instance
                      .collection('work_leads')
                      .add({
                        'ownerUserId': ownerUserId,
                        'leadUserId': userId,
                        'leadName': name,
                        'source': 'friends_list',
                        'createdAt': FieldValue.serverTimestamp(),
                      });
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('$name saved as potential work lead'),
                      ),
                    );
                  }
                },
                tooltip: 'Potential work lead',
                icon: const Icon(Icons.work_outline, color: AppTheme.neonCyan),
              ),
              IconButton(
                onPressed: () => context.push('/messaging'),
                tooltip: 'Message',
                icon: const Icon(
                  Icons.message_outlined,
                  color: AppTheme.neonCyan,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
