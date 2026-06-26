import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_theme.dart';
import '../../../shared/services/auth_service.dart';
import '../../../shared/services/content_safety_service.dart';

/// Blocked Users management screen — view and unblock users.
class BlockedUsersScreen extends StatefulWidget {
  const BlockedUsersScreen({super.key});

  @override
  State<BlockedUsersScreen> createState() => _BlockedUsersScreenState();
}

class _BlockedUsersScreenState extends State<BlockedUsersScreen> {
  List<Map<String, dynamic>> _blockedUsers = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadBlockedUsers();
  }

  Future<void> _loadBlockedUsers() async {
    final userId = context.read<AuthService>().currentUser?.uid;
    if (userId == null) {
      setState(() => _loading = false);
      return;
    }

    try {
      final safety = context.read<ContentSafetyService>();
      final users = await safety.getBlockedUsersDetailed(userId);
      if (mounted) {
        setState(() {
          _blockedUsers = users;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _unblock(String targetUserId) async {
    final userId = context.read<AuthService>().currentUser?.uid;
    if (userId == null) return;

    final safetyService = context.read<ContentSafetyService>();
    final messenger = ScaffoldMessenger.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Unblock User'),
        content: Text('Unblock $targetUserId?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text(
              'Unblock',
              style: TextStyle(color: AppTheme.neonGreen),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await safetyService.unblockUser(
        currentUserId: userId,
        targetUserId: targetUserId,
      );
      if (!mounted) return;

      messenger.showSnackBar(const SnackBar(content: Text('User unblocked')));
      _loadBlockedUsers();
    } catch (e) {
      if (!mounted) return;
      messenger.showSnackBar(
        const SnackBar(content: Text('Failed to unblock user')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.primaryBackground,
      appBar: AppBar(
        backgroundColor: AppTheme.primaryBackground,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
          onPressed: () =>
              context.canPop() ? context.pop() : context.go('/home'),
        ),
        title: const Row(
          children: [
            Icon(Icons.block, color: AppTheme.neonCyan, size: 22),
            SizedBox(width: 8),
            Text(
              'Blocked Users',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: AppTheme.neonCyan),
            )
          : _blockedUsers.isEmpty
          ? _buildEmpty()
          : _buildList(),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.check_circle_outline,
            color: AppTheme.neonGreen.withValues(alpha: 0.5),
            size: 64,
          ),
          const SizedBox(height: 16),
          const Text(
            'No blocked users',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'You haven\'t blocked anyone yet.',
            style: TextStyle(color: Colors.white.withValues(alpha: 0.6)),
          ),
        ],
      ),
    );
  }

  Widget _buildList() {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: _blockedUsers.length,
      separatorBuilder: (_, _) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final user = _blockedUsers[index];
        final userId = user['userId'] as String? ?? 'Unknown';

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.cardBackground,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
          ),
          child: Row(
            children: [
              const CircleAvatar(
                backgroundColor: AppTheme.surfaceColor,
                child: Icon(Icons.person_off, color: Colors.white54),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  userId,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              TextButton(
                onPressed: () => _unblock(userId),
                child: const Text(
                  'Unblock',
                  style: TextStyle(color: AppTheme.neonCyan),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
