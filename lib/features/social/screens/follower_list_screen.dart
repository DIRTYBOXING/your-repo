import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/design_tokens.dart';
import '../../../shared/services/social_service.dart';
import '../../../shared/widgets/dfc_network_image.dart';

/// ═══════════════════════════════════════════════════════════════════
///  FOLLOWER / FOLLOWING LIST — Tappable user list with follow toggle
///
///  • Tab 0 = Followers   • Tab 1 = Following
///  • Each tile shows avatar, name, role, follow/unfollow button
///  • Tap a tile → navigate to that user's profile
/// ═══════════════════════════════════════════════════════════════════
class FollowerListScreen extends StatefulWidget {
  final String userId;
  final String displayName;
  final int initialTab; // 0 = Followers, 1 = Following

  const FollowerListScreen({
    super.key,
    required this.userId,
    this.displayName = 'User',
    this.initialTab = 0,
  });

  @override
  State<FollowerListScreen> createState() => _FollowerListScreenState();
}

class _FollowerListScreenState extends State<FollowerListScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<Map<String, dynamic>> _followers = [];
  List<Map<String, dynamic>> _following = [];
  bool _loadingFollowers = true;
  bool _loadingFollowing = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 2,
      vsync: this,
      initialIndex: widget.initialTab,
    );
    _load();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final social = context.read<SocialService>();
    final followers = await social.getFollowers(widget.userId);
    final following = await social.getFollowing(widget.userId);
    if (mounted) {
      setState(() {
        _followers = followers;
        _following = following;
        _loadingFollowers = false;
        _loadingFollowing = false;
      });
    }
  }

  void _goBackSafely() {
    if (context.canPop()) {
      context.pop();
      return;
    }
    context.go('/home');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DesignTokens.bgPrimary,
      body: SafeArea(
        child: Column(
          children: [
            // ── Header ──
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 4, 16, 0),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(
                      Icons.arrow_back,
                      color: Colors.white,
                      size: 22,
                    ),
                    onPressed: _goBackSafely,
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      widget.displayName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),

            // ── Tab bar ──
            TabBar(
              controller: _tabController,
              indicatorColor: DesignTokens.neonCyan,
              labelColor: DesignTokens.neonCyan,
              unselectedLabelColor: Colors.white54,
              labelStyle: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
              tabs: [
                Tab(
                  text:
                      'Followers (${_loadingFollowers ? '…' : _followers.length})',
                ),
                Tab(
                  text:
                      'Following (${_loadingFollowing ? '…' : _following.length})',
                ),
              ],
            ),

            // ── Tab content ──
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildList(_followers, _loadingFollowers, 'No followers yet'),
                  _buildList(
                    _following,
                    _loadingFollowing,
                    'Not following anyone',
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildList(
    List<Map<String, dynamic>> users,
    bool loading,
    String emptyMsg,
  ) {
    if (loading) {
      return const Center(
        child: CircularProgressIndicator(color: DesignTokens.neonCyan),
      );
    }
    if (users.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.people_outline,
              size: 48,
              color: Colors.white.withValues(alpha: 0.12),
            ),
            const SizedBox(height: 8),
            Text(
              emptyMsg,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.3),
                fontSize: 14,
              ),
            ),
          ],
        ),
      );
    }
    return RefreshIndicator(
      color: DesignTokens.neonCyan,
      backgroundColor: DesignTokens.bgCard,
      onRefresh: _load,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: users.length,
        separatorBuilder: (_, _) =>
            Divider(height: 1, color: Colors.white.withValues(alpha: 0.04)),
        itemBuilder: (_, i) => _UserTile(user: users[i]),
      ),
    );
  }
}

/// ─── Single user row ───────────────────────────────────────────────────
class _UserTile extends StatelessWidget {
  final Map<String, dynamic> user;

  const _UserTile({required this.user});

  @override
  Widget build(BuildContext context) {
    final name =
        (user['displayName'] as String?) ??
        (user['userDisplayName'] as String?) ??
        'Unknown';
    final role =
        (user['role'] as String?) ?? (user['userRole'] as String?) ?? '';
    final avatarUrl =
        (user['photoUrl'] as String?) ??
        (user['userAvatarUrl'] as String?) ??
        '';
    final userId = (user['id'] as String?) ?? (user['userId'] as String?) ?? '';
    final initial = name.isNotEmpty ? name[0].toUpperCase() : '?';

    Color roleColor;
    switch (role) {
      case 'fighter':
        roleColor = DesignTokens.neonCyan;
        break;
      case 'coach':
        roleColor = DesignTokens.neonGreen;
        break;
      case 'promoter':
        roleColor = DesignTokens.neonMagenta;
        break;
      default:
        roleColor = Colors.grey;
    }

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: DfcCircleAvatar(
        imageUrl: avatarUrl,
        radius: 22,
        backgroundColor: roleColor.withValues(alpha: 0.15),
        fallbackText: initial,
        fallbackTextStyle: TextStyle(
          color: roleColor,
          fontWeight: FontWeight.w700,
        ),
      ),
      title: Text(
        name,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
      ),
      subtitle: role.isNotEmpty
          ? Text(
              role[0].toUpperCase() + role.substring(1),
              style: TextStyle(color: roleColor, fontSize: 11),
            )
          : null,
      trailing: Icon(
        Icons.chevron_right,
        color: Colors.white.withValues(alpha: 0.2),
        size: 20,
      ),
      onTap: () {
        if (userId.isNotEmpty) {
          context.push('/profile/$userId');
        }
      },
    );
  }
}
