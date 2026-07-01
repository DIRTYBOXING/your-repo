import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_theme.dart';
import '../../../shared/services/auth_service.dart';
import '../../../shared/widgets/dfc_network_image.dart';
import '../services/messaging_service.dart';

/// ═══════════════════════════════════════════════════════════════════════════
/// DFC GROUP CHAT SCREEN — Create new group conversations
///
/// - Search and select multiple members
/// - Set group name and optional photo
/// - Creates Firestore group conversation document
/// ═══════════════════════════════════════════════════════════════════════════
class CreateGroupChatScreen extends StatefulWidget {
  const CreateGroupChatScreen({super.key});

  @override
  State<CreateGroupChatScreen> createState() => _CreateGroupChatScreenState();
}

class _CreateGroupChatScreenState extends State<CreateGroupChatScreen> {
  final _nameCtrl = TextEditingController();
  final _searchCtrl = TextEditingController();
  final List<Map<String, String>> _selectedMembers = [];
  List<Map<String, String>> _searchResults = [];
  bool _searching = false;
  bool _creating = false;

  String? get _userId => context.read<AuthService>().currentUser?.uid;
  String get _userName =>
      context.read<AuthService>().currentUser?.displayName ?? 'User';
  String get _userPhoto =>
      context.read<AuthService>().currentUser?.photoURL ?? '';

  Future<void> _search(String query) async {
    if (query.length < 2) {
      setState(() => _searchResults = []);
      return;
    }
    setState(() => _searching = true);
    final service = context.read<MessagingService>();
    final results = await service.searchUsers(query, excludeUserId: _userId);
    if (!mounted) return;
    setState(() {
      _searchResults = results
          .where(
            (r) => !_selectedMembers.any((s) => s['uid'] == r['uid']),
          )
          .toList();
      _searching = false;
    });
  }

  void _addMember(Map<String, String> user) {
    setState(() {
      _selectedMembers.add(user);
      _searchResults.removeWhere((r) => r['uid'] == user['uid']);
      _searchCtrl.clear();
    });
  }

  void _removeMember(String uid) {
    setState(() {
      _selectedMembers.removeWhere((m) => m['uid'] == uid);
    });
  }

  Future<void> _createGroup() async {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty || _selectedMembers.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Enter a group name and add at least one member'),
        ),
      );
      return;
    }
    setState(() => _creating = true);
    try {
      final service = context.read<MessagingService>();
      final memberIds =
          _selectedMembers.map((m) => m['uid']!).toList();
      final memberNames = {
        for (final m in _selectedMembers) m['uid']!: m['displayName']!,
      };
      final memberPhotos = {
        for (final m in _selectedMembers) m['uid']!: m['photoUrl'] ?? '',
      };

      final convId = await service.createGroupConversation(
        creatorId: _userId!,
        creatorName: _userName,
        groupName: name,
        memberIds: memberIds,
        memberNames: memberNames,
        memberPhotoUrls: memberPhotos,
        creatorPhotoUrl: _userPhoto,
      );

      if (!mounted) return;
      Navigator.of(context).pop(convId);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to create group: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _creating = false);
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.primaryBackground,
      appBar: AppBar(
        backgroundColor: AppTheme.primaryBackground,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'New Group',
          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
        ),
        actions: [
          TextButton(
            onPressed: _creating ? null : _createGroup,
            child: _creating
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppTheme.neonCyan,
                    ),
                  )
                : const Text(
                    'CREATE',
                    style: TextStyle(
                      color: AppTheme.neonCyan,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1,
                    ),
                  ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Group name input
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.04),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: AppTheme.neonCyan.withValues(alpha: 0.15),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [
                        AppTheme.neonCyan.withValues(alpha: 0.3),
                        AppTheme.neonMagenta.withValues(alpha: 0.3),
                      ],
                    ),
                  ),
                  child: const Icon(
                    Icons.group,
                    color: Colors.white,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _nameCtrl,
                    style: const TextStyle(color: Colors.white, fontSize: 16),
                    decoration: InputDecoration(
                      hintText: 'Group name...',
                      hintStyle: TextStyle(
                        color: Colors.white.withValues(alpha: 0.3),
                      ),
                      border: InputBorder.none,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Selected members chips
          if (_selectedMembers.isNotEmpty)
            SizedBox(
              height: 48,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: _selectedMembers.length,
                itemBuilder: (context, index) {
                  final m = _selectedMembers[index];
                  return Container(
                    margin: const EdgeInsets.only(right: 8),
                    child: Chip(
                      backgroundColor:
                          AppTheme.neonCyan.withValues(alpha: 0.12),
                      side: BorderSide(
                        color: AppTheme.neonCyan.withValues(alpha: 0.3),
                      ),
                      label: Text(
                        m['displayName'] ?? 'User',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                        ),
                      ),
                      deleteIcon: const Icon(
                        Icons.close,
                        size: 16,
                        color: Colors.white54,
                      ),
                      onDeleted: () => _removeMember(m['uid']!),
                    ),
                  );
                },
              ),
            ),

          // Search input
          Container(
            margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.04),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.08),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.search,
                  color: Colors.white.withValues(alpha: 0.3),
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _searchCtrl,
                    style: const TextStyle(color: Colors.white, fontSize: 14),
                    decoration: InputDecoration(
                      hintText: 'Search members to add...',
                      hintStyle: TextStyle(
                        color: Colors.white.withValues(alpha: 0.3),
                      ),
                      border: InputBorder.none,
                    ),
                    onChanged: _search,
                  ),
                ),
                if (_searching)
                  const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppTheme.neonCyan,
                    ),
                  ),
              ],
            ),
          ),

          // Member count
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Row(
              children: [
                Text(
                  '${_selectedMembers.length} member${_selectedMembers.length == 1 ? '' : 's'} selected',
                  style: TextStyle(
                    color: AppTheme.neonCyan.withValues(alpha: 0.6),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),

          // Search results
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _searchResults.length,
              itemBuilder: (context, index) {
                final user = _searchResults[index];
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Container(
                    width: 40,
                    height: 40,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [AppTheme.neonCyan, AppTheme.neonMagenta],
                      ),
                    ),
                    child: ClipOval(
                      child: (user['photoUrl'] ?? '').isNotEmpty
                          ? DfcNetworkImage(
                              url: user['photoUrl']!,
                            )
                          : Center(
                              child: Text(
                                (user['displayName'] ?? '?')[0].toUpperCase(),
                                style: const TextStyle(
                                  color: Colors.black,
                                  fontWeight: FontWeight.w900,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                    ),
                  ),
                  title: Text(
                    user['displayName'] ?? 'User',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  trailing: IconButton(
                    icon: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: AppTheme.neonCyan.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AppTheme.neonCyan.withValues(alpha: 0.3),
                        ),
                      ),
                      child: const Icon(
                        Icons.add,
                        color: AppTheme.neonCyan,
                        size: 18,
                      ),
                    ),
                    onPressed: () => _addMember(user),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
