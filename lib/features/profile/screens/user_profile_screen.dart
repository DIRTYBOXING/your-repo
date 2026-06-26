import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../shared/services/auth_service.dart';
import '../../../shared/services/social_service.dart';
import '../../../shared/services/enhanced_friends_service.dart';
import '../../../shared/widgets/dfc_network_image.dart';
import '../../messaging/services/messaging_service.dart';
import '../../social/widgets/follow_button.dart';

/// ═══════════════════════════════════════════════════════════════════════════
/// VIEW OTHER USER PROFILE
/// Shows another user's public profile with follow + message actions.
/// ═══════════════════════════════════════════════════════════════════════════

const _accent = Color(0xFF00F5FF);

class UserProfileScreen extends StatefulWidget {
  final String userId;
  const UserProfileScreen({super.key, required this.userId});

  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  final _firestore = FirebaseFirestore.instance;
  final _social = SocialService();
  Map<String, dynamic>? _user;
  bool _loading = true;
  int _followers = 0;
  int _following = 0;
  int _posts = 0;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    try {
      final doc = await _firestore.collection('users').doc(widget.userId).get();
      if (doc.exists) {
        _user = {'id': doc.id, ...doc.data()!};
      }

      // Load stats in parallel
      final results = await Future.wait([
        _social.getFollowerCount(widget.userId),
        _social.getFollowingCount(widget.userId),
        _firestore
            .collection('posts')
            .where('userId', isEqualTo: widget.userId)
            .count()
            .get(),
        _firestore
            .collection('posts')
            .where('authorId', isEqualTo: widget.userId)
            .count()
            .get(),
      ]);

      _followers = results[0] as int;
      _following = results[1] as int;
      final userIdPosts = (results[2] as AggregateQuerySnapshot).count ?? 0;
      final authorIdPosts = (results[3] as AggregateQuerySnapshot).count ?? 0;
      _posts = userIdPosts == 0 ? authorIdPosts : userIdPosts + authorIdPosts;
    } catch (e) {
      debugPrint('Error loading user profile: $e');
    }
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _handleProfileAction(String action) async {
    final friends = context.read<EnhancedFriendsService>();
    final name = _user?['displayName'] as String? ?? 'this user';

    switch (action) {
      case 'block':
        final confirmed = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            backgroundColor: const Color(0xFF1A2540),
            title: const Text(
              'Block User',
              style: TextStyle(color: Colors.white),
            ),
            content: Text(
              'Block $name? They won\'t be able to message you or see your activity.',
              style: const TextStyle(color: Colors.white70),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text(
                  'Block',
                  style: TextStyle(color: Colors.redAccent),
                ),
              ),
            ],
          ),
        );
        if (confirmed == true && mounted) {
          await friends.blockUser(widget.userId);
          if (mounted) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text('$name has been blocked')));
          }
        }
        break;
      case 'mute':
        await friends.muteUser(widget.userId);
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('$name has been muted')));
        }
        break;
    }
  }

  String? _firstNonEmptyUserField(List<String> keys) {
    final user = _user;
    if (user == null) {
      return null;
    }

    for (final key in keys) {
      final value = user[key]?.toString().trim();
      if (value != null && value.isNotEmpty) {
        return value;
      }
    }

    return null;
  }

  Widget _buildProfileAvatar(String name, String? avatarUrl) {
    final fallback = Container(
      width: 96,
      height: 96,
      decoration: const BoxDecoration(
        color: Color(0xFF1A2540),
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: Text(
        name.isNotEmpty ? name[0].toUpperCase() : '?',
        style: const TextStyle(
          color: _accent,
          fontWeight: FontWeight.bold,
          fontSize: 32,
        ),
      ),
    );

    if (avatarUrl == null || avatarUrl.isEmpty) {
      return fallback;
    }

    return ClipOval(
      child: SizedBox(
        width: 96,
        height: 96,
        child: DfcNetworkImage(
          url: avatarUrl,
          width: 96,
          height: 96,
          errorWidget: fallback,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentUid = context.read<AuthService>().currentUser?.uid;

    if (_loading) {
      return Scaffold(
        backgroundColor: const Color(0xFF050A14),
        appBar: AppBar(backgroundColor: const Color(0xFF0A1628), elevation: 0),
        body: const Center(child: CircularProgressIndicator(color: _accent)),
      );
    }

    if (_user == null) {
      return Scaffold(
        backgroundColor: const Color(0xFF050A14),
        appBar: AppBar(backgroundColor: const Color(0xFF0A1628), elevation: 0),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.person_off,
                size: 64,
                color: Colors.white.withValues(alpha: 0.2),
              ),
              const SizedBox(height: 12),
              const Text(
                'User not found',
                style: TextStyle(color: Colors.white54, fontSize: 16),
              ),
            ],
          ),
        ),
      );
    }

    final name = _user!['displayName'] as String? ?? 'User';
    final photo =
        _firstNonEmptyUserField(['pageAvatarUrl', 'photoUrl', 'photoURL']) ??
        '';
    final coverImage = _firstNonEmptyUserField([
      'pageCoverUrl',
      'pageBannerUrl',
      'coverPhotoUrl',
      'bannerUrl',
    ]);
    final role = _user!['role'] as String? ?? 'fan';
    final bio = _user!['bio'] as String? ?? '';
    final username = _user!['username'] as String? ?? '';
    final city = _user!['city'] as String? ?? '';
    final country = _user!['country'] as String? ?? '';
    final location = [city, country].where((s) => s.isNotEmpty).join(', ');
    final isSelf = widget.userId == currentUid;

    return Scaffold(
      backgroundColor: const Color(0xFF050A14),
      body: CustomScrollView(
        slivers: [
          // ── Hero header ──
          SliverAppBar(
            pinned: true,
            expandedHeight: 260,
            backgroundColor: const Color(0xFF0A1628),
            actions: isSelf
                ? null
                : [
                    PopupMenuButton<String>(
                      icon: const Icon(Icons.more_vert, color: Colors.white70),
                      color: const Color(0xFF1A2540),
                      onSelected: _handleProfileAction,
                      itemBuilder: (_) => const [
                        PopupMenuItem(
                          value: 'block',
                          child: Row(
                            children: [
                              Icon(
                                Icons.block,
                                color: Colors.redAccent,
                                size: 20,
                              ),
                              SizedBox(width: 10),
                              Text(
                                'Block User',
                                style: TextStyle(color: Colors.white),
                              ),
                            ],
                          ),
                        ),
                        PopupMenuItem(
                          value: 'mute',
                          child: Row(
                            children: [
                              Icon(
                                Icons.volume_off,
                                color: Colors.orangeAccent,
                                size: 20,
                              ),
                              SizedBox(width: 10),
                              Text(
                                'Mute User',
                                style: TextStyle(color: Colors.white),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  if (coverImage != null && coverImage.isNotEmpty)
                    Positioned.fill(
                      child: DfcNetworkImage(
                        url: coverImage,
                      ),
                    ),
                  // Gradient background
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withValues(alpha: 0.14),
                          _accent.withValues(alpha: 0.08),
                          const Color(0xFF050A14),
                        ],
                      ),
                    ),
                  ),
                  // Avatar + info
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(height: 40),
                      // Avatar
                      Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: _accent, width: 2),
                          boxShadow: [
                            BoxShadow(
                              color: _accent.withValues(alpha: 0.3),
                              blurRadius: 16,
                            ),
                          ],
                        ),
                        child: _buildProfileAvatar(name, photo),
                      ),
                      const SizedBox(height: 12),
                      // Name
                      Text(
                        name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (username.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          '@$username',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.35),
                            fontSize: 13,
                          ),
                        ),
                      ],
                      const SizedBox(height: 6),
                      // Role chip
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: _accent.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: _accent.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Text(
                          role.toUpperCase(),
                          style: const TextStyle(
                            color: _accent,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            title: ClipRRect(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                child: Text(
                  name,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
          ),

          // ── Stats row ──
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _statCol('$_posts', 'Posts'),
                  GestureDetector(
                    onTap: () => context.push(
                      '/followers/${widget.userId}?name=${Uri.encodeComponent(name)}&tab=0',
                    ),
                    child: _statCol('$_followers', 'Followers'),
                  ),
                  GestureDetector(
                    onTap: () => context.push(
                      '/followers/${widget.userId}?name=${Uri.encodeComponent(name)}&tab=1',
                    ),
                    child: _statCol('$_following', 'Following'),
                  ),
                ],
              ),
            ),
          ),

          // ── Action buttons ──
          if (!isSelf && currentUid != null)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 8,
                ),
                child: Row(
                  children: [
                    // Add Friend button
                    Expanded(
                      child: _AddFriendButton(
                        currentUserId: currentUid,
                        targetUserId: widget.userId,
                        targetName: name,
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Message button — opens direct DM
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.mail_outline, size: 18),
                        label: const Text('Message'),
                        onPressed: () => _openDirectMessage(
                          context,
                          currentUid: currentUid,
                          otherUserId: widget.userId,
                          otherName: name,
                          otherPhoto: photo,
                        ),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: _accent,
                          side: const BorderSide(color: _accent),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Follow button
                    FollowButton(
                      currentUserId: currentUid,
                      targetUserId: widget.userId,
                      onChanged: (_) => _loadProfile(),
                    ),
                  ],
                ),
              ),
            ),

          // ── Bio ──
          if (bio.isNotEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 12, 24, 4),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.04),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    bio,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.7),
                      fontSize: 14,
                      height: 1.5,
                    ),
                  ),
                ),
              ),
            ),

          // ── Location ──
          if (location.isNotEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 8,
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.location_on,
                      color: _accent.withValues(alpha: 0.5),
                      size: 16,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      location,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.4),
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // ── Spacer bottom ──
          const SliverToBoxAdapter(child: SizedBox(height: 60)),
        ],
      ),
    );
  }

  /// Facebook-style: Message button opens direct DM with this user
  Future<void> _openDirectMessage(
    BuildContext context, {
    required String currentUid,
    required String otherUserId,
    required String otherName,
    required String otherPhoto,
  }) async {
    try {
      final auth = context.read<AuthService>();
      final msgService = context.read<MessagingService>();
      final currentUser = auth.currentUser;
      if (currentUser == null) return;

      final conversationId = await msgService.createConversation(
        currentUserId: currentUid,
        currentUserName: currentUser.displayName ?? 'You',
        currentUserPhotoUrl: currentUser.photoURL ?? '',
        otherUserId: otherUserId,
        otherUserName: otherName,
        otherUserPhotoUrl: otherPhoto,
      );

      if (!context.mounted) return;
      context.push(
        '/messaging/chat/$conversationId',
        extra: {
          'otherName': otherName,
          'otherPhotoUrl': otherPhoto,
          'otherUserId': otherUserId,
        },
      );
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open conversation')),
        );
      }
    }
  }

  Widget _statCol(String value, String label) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.4),
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// ADD FRIEND BUTTON — Facebook-style friend request from profile
// ═══════════════════════════════════════════════════════════════════════════
class _AddFriendButton extends StatefulWidget {
  final String currentUserId;
  final String targetUserId;
  final String targetName;

  const _AddFriendButton({
    required this.currentUserId,
    required this.targetUserId,
    required this.targetName,
  });

  @override
  State<_AddFriendButton> createState() => _AddFriendButtonState();
}

class _AddFriendButtonState extends State<_AddFriendButton> {
  _FriendStatus _status = _FriendStatus.none;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _checkStatus();
  }

  Future<void> _checkStatus() async {
    try {
      final friendsService = context.read<EnhancedFriendsService>();
      final areFriends = await friendsService.areFriends(
        widget.currentUserId,
        widget.targetUserId,
      );
      if (areFriends) {
        setState(() {
          _status = _FriendStatus.friends;
          _loading = false;
        });
        return;
      }
      // Check pending — simplified check
      setState(() {
        _status = _FriendStatus.none;
        _loading = false;
      });
    } catch (_) {
      setState(() => _loading = false);
    }
  }

  Future<void> _sendRequest() async {
    setState(() => _loading = true);
    try {
      final friendsService = context.read<EnhancedFriendsService>();
      await friendsService.sendFriendRequest(recipientId: widget.targetUserId);
      setState(() {
        _status = _FriendStatus.pending;
        _loading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Friend request sent to ${widget.targetName}'),
            backgroundColor: const Color(0xFF1A2540),
          ),
        );
      }
    } catch (e) {
      setState(() => _loading = false);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('$e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return OutlinedButton(
        onPressed: null,
        style: OutlinedButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          padding: const EdgeInsets.symmetric(vertical: 10),
        ),
        child: const SizedBox(
          width: 16,
          height: 16,
          child: CircularProgressIndicator(strokeWidth: 2, color: _accent),
        ),
      );
    }

    switch (_status) {
      case _FriendStatus.friends:
        return OutlinedButton.icon(
          icon: const Icon(Icons.check_circle, size: 18),
          label: const Text('Friends'),
          onPressed: null,
          style: OutlinedButton.styleFrom(
            foregroundColor: const Color(0xFF4CAF50),
            side: const BorderSide(color: Color(0xFF4CAF50)),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            padding: const EdgeInsets.symmetric(vertical: 10),
          ),
        );
      case _FriendStatus.pending:
        return OutlinedButton.icon(
          icon: const Icon(Icons.hourglass_top, size: 18),
          label: const Text('Pending'),
          onPressed: null,
          style: OutlinedButton.styleFrom(
            foregroundColor: Colors.amber,
            side: const BorderSide(color: Colors.amber),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            padding: const EdgeInsets.symmetric(vertical: 10),
          ),
        );
      case _FriendStatus.none:
        return ElevatedButton.icon(
          icon: const Icon(Icons.person_add, size: 18),
          label: const Text('Add Friend'),
          onPressed: _sendRequest,
          style: ElevatedButton.styleFrom(
            backgroundColor: _accent,
            foregroundColor: Colors.black,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            padding: const EdgeInsets.symmetric(vertical: 10),
          ),
        );
    }
  }
}

enum _FriendStatus { none, pending, friends }
