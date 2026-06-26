import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/design_tokens.dart';
import '../../../shared/services/auth_service.dart';
import '../../../shared/services/content_safety_service.dart';
import '../../../shared/widgets/dfc_network_image.dart';

/// ═══════════════════════════════════════════════════════════════════════════
/// MUTED USERS SCREEN — parallel to BlockedUsersScreen
/// ═══════════════════════════════════════════════════════════════════════════
class MutedUsersScreen extends StatefulWidget {
  const MutedUsersScreen({super.key});

  @override
  State<MutedUsersScreen> createState() => _MutedUsersScreenState();
}

class _MutedUsersScreenState extends State<MutedUsersScreen> {
  List<Map<String, dynamic>> _mutedUsers = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadMutedUsers();
  }

  Future<void> _loadMutedUsers() async {
    final userId = context.read<AuthService>().currentUser?.uid;
    if (userId == null) {
      setState(() => _loading = false);
      return;
    }
    try {
      final safety = context.read<ContentSafetyService>();
      final users = await safety.getMutedUsersDetailed(userId);
      if (mounted) {
        setState(() {
          _mutedUsers = users;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _unmute(String targetUserId) async {
    final userId = context.read<AuthService>().currentUser?.uid;
    if (userId == null) return;

    final safetyService = context.read<ContentSafetyService>();
    final messenger = ScaffoldMessenger.of(context);

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: DesignTokens.bgCard,
        title: const Text('Unmute User', style: TextStyle(color: Colors.white)),
        content: const Text(
          'You will see posts from this user again.',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text(
              'Unmute',
              style: TextStyle(color: DesignTokens.neonGreen),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await safetyService.unmuteUser(
        currentUserId: userId,
        targetUserId: targetUserId,
      );
      messenger.showSnackBar(const SnackBar(content: Text('User unmuted')));
      _loadMutedUsers();
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text('Failed: $e'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DesignTokens.bgPrimary,
      appBar: AppBar(
        backgroundColor: DesignTokens.bgSecondary,
        title: const Text(
          'Muted Users',
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.white54),
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: DesignTokens.neonCyan),
            )
          : _mutedUsers.isEmpty
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.volume_off,
                    size: 48,
                    color: Colors.white.withValues(alpha: 0.15),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'No muted users',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.3),
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: _mutedUsers.length,
              separatorBuilder: (_, _) => Divider(
                height: 1,
                color: Colors.white.withValues(alpha: 0.06),
              ),
              itemBuilder: (context, index) {
                final user = _mutedUsers[index];
                final userId = user['userId'] as String? ?? '';
                final name = user['displayName'] as String? ?? userId;
                final avatar = user['photoUrl'] as String?;
                final mutedAt = user['mutedAt'] as DateTime?;

                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: DfcCircleAvatar(
                    imageUrl: avatar,
                    fallbackText: name.isNotEmpty ? name[0].toUpperCase() : '?',
                    fallbackTextStyle: const TextStyle(
                      color: DesignTokens.neonCyan,
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
                  subtitle: mutedAt != null
                      ? Text(
                          'Muted ${_formatDate(mutedAt)}',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.3),
                            fontSize: 11,
                          ),
                        )
                      : null,
                  trailing: TextButton(
                    onPressed: () => _unmute(userId),
                    child: const Text(
                      'Unmute',
                      style: TextStyle(
                        color: DesignTokens.neonGreen,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }

  String _formatDate(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inDays > 30) return '${dt.day}/${dt.month}/${dt.year}';
    if (diff.inDays > 0) return '${diff.inDays}d ago';
    if (diff.inHours > 0) return '${diff.inHours}h ago';
    return 'just now';
  }
}
